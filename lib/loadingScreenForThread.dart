import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerThread extends StatelessWidget {
  const ShimmerThread({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 50,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _textLine(),
          Expanded(child: dataListView()),
        ],
      ),
    );
  }

  Padding dataListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildIcon(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Row _textLine() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 5,
              color: Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }

  Divider _divider() {
    return const Divider(
      color: Colors.grey,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }

  Shimmer _buildIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.delete,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.add_reaction_outlined,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.edit,
                color: Colors.grey[300],
              ),
            ],
          )
        ],
      ),
    );
  }
}
